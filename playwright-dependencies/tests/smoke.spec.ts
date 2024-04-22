import { test, expect } from '@playwright/test';

test('smokeTest', async ({ page }) => {
  const containerPort = process.env.CONTAINER_PORT_EXPORTED;
  const url = "localhost:" + containerPort;
  
  await page.goto(url);

  await page.getByRole('button', { name: 'Sign In' }).click();
  await page.getByLabel('Email Address').click();
  await page.getByLabel('Email Address').press('Home');
  await page.getByLabel('Email Address').fill('test@liferay.com');
  await page.getByLabel('Email Address').press('Tab');
  await page.getByLabel('Password').fill('test');
  await page.getByLabel('Password').press('Tab');
  await page.getByLabel('Remember Me').press('Tab');
  await page.getByLabel('Sign In- Loading').getByRole('button', { name: 'Sign In' }).press('Enter');
  await page.waitForTimeout(3000);

  await page.getByLabel('Password', { exact: true }).click();
  await page.getByLabel('Password', { exact: true }).fill('a');
  await page.getByLabel('Password', { exact: true }).press('Tab');
  await page.getByLabel('Reenter Password').fill('a');
  await page.getByLabel('Reenter Password').press('Tab');
  await page.getByRole('button', { name: 'Save' }).press('Enter');
  await page.getByRole('button', { name: 'Done' }).click();
  await page.waitForTimeout(3000);

  await page.getByLabel('Test Test User Profile').click();
  await page.getByRole('menuitem', { name: 'Account Settings' }).click();
  await page.getByRole('link', { name: 'Password' }).click();
  await page.getByLabel('Current Password Required').click();
  await page.getByLabel('Current Password Required').fill('a');
  await page.getByLabel('New Password Required').click();
  await page.getByLabel('New Password Required').fill('test');
  await page.getByLabel('Reenter Password Required').click();
  await page.getByLabel('Reenter Password Required').fill('test');
  await page.getByRole('button', { name: 'Save' }).click();
});